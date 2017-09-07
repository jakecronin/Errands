<img src="https://github.com/jakecronin/Errands/blob/master/ErrandsLogo.png" width="200"/>
# Errands
Calculate the optimal order in which to go to multiple destinations using predicted traffic conditions.
![Itunes Link](https://itunes.apple.com/us/app/errandz/id1257418211?mt=8 "Link to App on Itunes")
*Swift, MapKit, Graph Optimization*

# Challenges
At first, this problem resembles the traveling salesman problem, but the use of predicted traffic conditions adds an extra layer of complexity.
Because I wanted to consider traffic data, the travel time between each destination changes when the time of departure is modified. This means that the travel time between any two destinations will need to be calculated multiple times.
I ultimately chose a depth first search approach that trims paths once they exceed the current minimum travel time. This approach makes O(numDestinations!) api calls in the wost case scenario. While Apple's Maps api throttles excessive api calls, I have found that a solution can be found for up to 6 destinations. 

# Motivation
Carpooling is a wonderful way to reduce traffic and conserve gas, but carpoolers often run into the issue of "who to drop off first". When there are multiple people that need to be dropped off or picked up from different locations, it is not a trivial problem to decide the fastest order to pick up or drop off these people, especially in places where traffic is variable throughout the day and makes a major impact on travel time.  
A common use case is someone needs to run some errands, and does not know what store to go to first.

# Screenshots

Displaying Results
<img src="https://github.com/jakecronin/Errands/blob/master/Images/Results.jpg" width="200"/>

Adding Destinations
<img src="https://github.com/jakecronin/Errands/blob/master/Images/Add_Locations.jpg" width="200"/>

Grabbing Location
<img src="https://github.com/jakecronin/Errands/blob/master/Images/Get_Location.jpg" width="200"/>
