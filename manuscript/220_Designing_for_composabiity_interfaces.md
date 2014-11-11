Designing for composability - Interfaces
===============================

Some objects are harder to compose with other objects, others are easier. Of course, we are striving for the higher composability. There are numerous factors influencing this. I already discussed some of them indirectly, so time to sum things up and fill in the gaps. This chapter will deal with the role interfaces play in achieving high composability and the next one will deal with something called *protocols*.

### Classes vs interfaces

As we said, a sender is composed with a recipient by obtaining a reference to it. Also, we said that we want our senders to be able to send messages to many different recipients. This is, of course, done using polymorphism. 

So, one of the questions we have to ask ourselves in our quest for high composability is: on what should a sender depend on to be able to work with as many recipients as possible? Should it depend on classes or interfaces? In other words, when we plug in an object as a message receipient like this:

{lang="csharp"}
~~~
public Sender(Recipient recipient)
{
  this._recipient = recipient;
}
~~~

Should the `Recipient` be a class or an interface?

If we assume that `Recipient` is a class, we can get the composability we want by deriving another class from it and implementing abstract methods or overriding virtual ones. However, depending on a class as a base type for a recipient has the following disadvantages:

1.  The recipient class may have some real dependencies. For example, if `Recipient` class depends on Windows Communication Foundation stack, then all classes depending directly on `Recipient` will indirectly depend on WCF, including our `Sender`. The more damaging version of this problem is where such a `Recipient` class actually opens a connection in a constructor - the subclasses are unable to prevent it, no matter if they like it or not, because a subclass has to call a superclass' constructor.
2.  Each class deriving from `Recipient` must invoke `Recipient`'s constructor, which, depending on the complexity of the superclass, may be smaller or bigger trouble, depending on what kind of parameters the constructor accepts and what it does.
3.  In languages like C\#, where only single inheritance exists, by deriving from `Recipient` class, we use up the only inheritance slot, further constraining our design.
4.  We must make sure to mark all the methods of `Recipient` class as `virtual` to enable overriding them by subclasses. otherwise, we won't have full composability, because subclasses, not being able to override some methods, will be very constrained in what they can do.

As you see, there are some difficulties using classes as "slots for composability", even if composition is technically possible this way. Interfaces are far better, just because they do not have the above disadvantages.

It is decided then, If a sender wants to be composable with different recipients, it has to accept a reference to recipient in form of interface reference. We can say that, by being lightweight and implementationless, **interfaces can be treated as "slots" for plugging in different objects**.

In fact, one way to depict a fact that a class implements an interface on UML diagram looks like the class is exposing a plug. Thus, it seems that the "interface as slot for pluggability" concept is not so unusual.

![ConcreteRecipient class implementing three interfaces in UML. The interfaces are shown as "connectors" meaning the class can be plugged into anything that uses any of the three interfaces](images/lollipop.png)

The big thing about the design approach I am trying to introduce you to is that we are taking this concept to the extreme, making it THE most important aspect of this approach.


### Events/callbacks vs interfaces - few words on roles

Did I just say that composability is "THE most important aspect of our design approach"? Wow, that's quite a statement, isn't it? Unfortunately for me, it also lets you jump with the following argument:
"Hey, interfaces are not the most extreme way of achieving composability! What about events that e.g. C\# supports? Or callbacks that are supported by some other languages? Wouldn't it make the classes even more context-independent, if we connected them using events or callbacks, not interfaces?"

Actually, it would, and we could, but it would also strip us from another very important aspect of our design approach that I did not mention explicitly until now. This aspect is: roles.

When we take an example method that sends some messages to two recipients held as interfaces:

{lang="csharp"}
~~~
private readonly Recipient1 recipient1;
private readonly Recipient2 recipient2;

public void SendSomethingToRecipients()
{
  recipient1.DoX();
  recipient1.DoY();
  recipient2.DoZ();
}
~~~

and we compare it with similar effect achieved using event/callback invocation:

{lang="csharp"}
~~~
private readonly Action DoX;
private readonly Action DoY;
private readonly Action DoZ;

public void SendSomethingToRecipients()
{
  DoX();
  DoY();
  DoZ();
}
~~~

We can see that in the second case we are losing the notion of which message belongs to which recipient - each event is standalone from the point of view of the sender. This is unfortunate, because in our design approach, we want to highlight the roles each receiver plays in the communication, to make the communication itself readable and logical. Also, ironically, decoupling using events or callbacks can make composability harder. This is because roles tell us which sets of behaviors belong together and thus, need to change together. If each behavior is triggered using a separate event or callback, an overhead is placed on us to remember which behaviors should be changed together, and which ones can change independently.

This does not mean that events or callbacks are bad. It's just that they are not a fit replacement for interfaces - in reality, their purpose is a little bit different. We use events or callbacks not to do somebody to do something, but to indicate what happened (that's why we call them events, after all...). This fits well the observer pattern we already talked about in the previous chapter. So, instead of using observer objects, we may consider using events or callbacks instead (as in everything, there are some tradeoffs for each of the solutions). In other words, events and callbacks have their role in the composition, but they are fit for a case so specific, that they cannot be used as a default choice for the composition. The advantage of the interfaces is that they bind together messages, which should be implemented cohesively, and convey roles in the communication, which improves readability.

### Small interfaces

Ok, so we said that he interfaces are "the way to go" for reaching the strong composability we're striving for. Does merely using interfaces guarantee us that the composability is going to be strong? The answer is "no" - while using interfaces is a necessary step in the right direction, it alone does not produce the best composability.

One of the other things we need to consider is the size of interfaces. Let's state one thing that is obvious in regard to this:

**All other things equal, smaller interfaces (i.e. with less methods) are easier to implement that bigger interfaces.**

The obvious conclusion from this is that if we want to have really strong composability, our "slots", i.e. interfaces, have to be as small as possible (but not smaller - see previous section on interfaces vs
events/callbacks). Of course, we cannot achieve this just by blindly removing methods from the interfaces, because this would break classes that actually use these methods e.g. when someone is using an interface implementation like this:

{lang="csharp"}
~~~
public void Process(Recipient recipient)
{
  recipient.DoSomething();
  recipient.DoSomethingElse();
}
~~~

It is impossible to remove either of the methods from the `Recipient` interface, because it would cause a compile error saying that we are trying to use a method that does not exist.

So, what do we do then? We try to separate groups of methods used by different senders and move them to separate interfaces, so that each sender has access only to the methods it needs. After all, a class can implement more than one interface, like this:

{lang="csharp"}
~~~
public class ImplementingObject 
: InterfaceForSender1, 
  InterfaceForSender2,
  InterfaceForSender3
{ ... }
~~~

This notion of creating a separate interface per sender instead of a single big interface for all senders is known as the Interface Segregation Principle[^interfacesegregation].

#### A simple example: separation of reading from writing

Let's assume we have a class representing organizational structure in our application. This application exposes two APIs. Through the first one, it is notified on any changes made to the organizational structure by an administrator. The second one is for client-side operations on the organizational data, like listing all employees. The interface for the organizational structure class may contain methods used by both these APIs:

{lang="csharp"}
~~~
public interface 
OrganizationStructure
{
  //////////////////////
  //administrative part:
  //////////////////////  
  
  void Make(Change change);
  //...other administrative methods
  
  //////////////////////
  //client-side part:
  //////////////////////
  
  void ListAllEmployees(
    EmployeeDestination destination);
  //...other client-side methods  
}
~~~

However, the administrative API handling is done by a different code than the client-side API handling.  Thus, the administrative part has no use of the knowledge about listing employees and vice-versa - the client-side one has no interest in making administrative changes. We can use this knowledge to separate our interface into two:

{lang="csharp"}
~~~
public interface
OrganizationalStructureAdminCommands
{
  void Make(Change change);
  //... other administrative methods
}

public interface
OrganizationalStructureClientCommands
{
  void ListAllEmployees(
    EmployeeDestination destination);
  //... other client-side methods
}
~~~

Note that this does not constrain the implementation of these interfaces - a real class can still implement both of them if this is desired:

{lang="csharp"}
~~~
public class InMemoryOrganizationalStructure
: OrganizationalStructureAdminCommands,
  OrganizationalStructureClientCommands
{
  //...
}
~~~

In this approach, we create more interfaces (which some may not like), but that shouldn't bother us much, because in return, each interface is easier to implement. In other words, if a class is using one of the interfaces, it is easier to write another implementation of it, because there is less methods to implement. This means that composability is enhanced, which is what we want the most. 

It pays off. For example, one day, we may get a requirement that all writes to the organizational structure have to be traced. In such case, All we have to do is to create new class implementing `OrganizationalStructureAdminCommands` which will wrap the original methods with a notification to an observer (that can be either the trace that is required or anything else we like):

{lang="csharp"}
~~~
public class NotifyingAdminComands : OrganizationalStructureAdminCommands
{
  public NotifyingCommands(
    OrganizationalStructureAdminCommands wrapped,
    ChangeObserver observer)
  {
    _wrapped = wrapped;
    _observer = observer;
  }

  void Make(Change change)
  { 
    _wrapped.Make(change);
    _observer.NotifyAbout(change);
  }
  
  //...other administrative methods
}
~~~

If we did not separate interfaces for admin and client access, in our `NotifyingAdminComands` class, we would have to implement the `ListAllEmployees` method (and others) and make it delegate to the original wrapped instance. This is not difficult, but it's unnecessary effort. Splitting the interface into two smaller ones spared us this trouble.

#### Interfaces should depend on abstractions, not implementation details

You might think that interface is an abstraction by definition. I believe otherwise - while interfaces abstract away the concrete type of the class that is implementing the interface, they may still contain some
other things not abstracted, exposing some implementation details. Let's look at the following interface:

{lang="csharp"}
~~~
public interface Basket
{
  void WriteTo(SqlConnection sqlConnection);
  bool IsAllowedToEditBy(SecurityPrincipal user);
}
~~~

See the arguments of those methods? `SqlConnection` is a library object for interfacing directly with SQL Server database, so it is a very concrete dependency. `SecurityPrincipal` is one of the core classes of
.NET's authentication and authorization model for local users database and Active Directory, so again, a very concrete dependency. With dependencies like that, it will be very hard to write other implementations of this interface, because we will be forced to drag around concrete dependencies and mostly will not be able to work around that if we want something different. Thus, we may say that these are implementation details exposed in the interface that, for this reason, cannot be abstract. It is essential to abstract these implementation details away, e.g. like this:

{lang="csharp"}
~~~
public interface Basket
{
  void WriteTo(ProductOutput output);
  bool IsAllowedToEditBy(BasketOwner user);
}
~~~

This is better. For example, as `ProductOutput` is a higher level abstraction (most probably an interface, as we discussed earlier) no implementation of the `WriteTo` method must be tied to any particular storage kind. This means that we are more free to develop different implementations of this method. In addition, each implementation of the `WriteTo` method is more useful as it can be reused with different kinds of `ProducOutput`s.

So the general rule is: make interfaces real abstractions by abstracting away the implementation details from them. Only then are you free to create different implementations of the interface that are not constrained by dependencies they do not want or need.

[^interfacesegregation]: http://www.objectmentor.com/resources/articles/isp.pdf