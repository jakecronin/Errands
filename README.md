<img src="https://github.com/jakecronin/Errands/blob/master/ErrandsLogo.png" width="200"/>

# Errands
Calculate the optimal order in which to go to multiple destinations using predicted traffic conditions.
![Itunes Link](https://itunes.apple.com/us/app/errandz/id1257418211?mt=8 "Link to App on Itunes")
*Swift, MapKit, Graph Optimization*

# Challenges
At first, this problem resembles the traveling salesman problem, but the use of predicted traffic conditions adds an extra layer of complexity. Because I wanted to consider traffic data, the travel time between each destination changes when the time of departure is modified. This means that the travel time between any two destinations will need to be calculated multiple times.

I ultimately chose a depth first search approach that trims paths once they exceed the current minimum travel time. This approach makes O(numDestinations!) api calls in the wost case scenario. While Apple's Maps api throttles excessive api calls, I have found that a solution can be found for up to 6 destinations. 

# Motivation
Carpooling is a wonderful way to reduce traffic and conserve gas, but carpoolers often run into the issue of "who to drop off first". This is not a trivial problem especially when trying to consider traffic. Errands provides an easy solution to not only the "who to drop off first" problem, but can also be useful for any other errands.

# Screenshots

Displaying Results:

<img src="https://github.com/jakecronin/Errands/blob/master/Images/Results.jpg" width="200"/>

Adding Destinations:

<img src="https://github.com/jakecronin/Errands/blob/master/Images/Add_Locations.jpg" width="200"/>

Grabbing Location:

<img src="https://github.com/jakecronin/Errands/blob/master/Images/Get_Location.jpg" width="200"/>
