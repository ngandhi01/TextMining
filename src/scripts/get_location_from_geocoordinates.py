"""

	get_location_from_geocoordinates.py

	Takes lat/long pairs, uses GeoPy to get locations
	Based off this link: https://www.thepythoncode.com/article/get-geolocation-in-python

"""

from geopy.geocoders import Nominatim
import pycountry_convert as pc
import time
from pprint import pprint

# instantiate a new Nominatim client
app = Nominatim(user_agent="covid")

def get_address_by_location(latitude, longitude, language="en"):
    
    """
    This function returns an address as raw from a location
    will repeat until success
    """

    # build coordinates string to pass to reverse() function
    coordinates = f"{latitude}, {longitude}"
    # sleep for a second to respect Usage Policy
    time.sleep(1)
    try:
        return app.reverse(coordinates, language=language).raw
    except:
        return get_address_by_location(latitude, longitude)

def get_country_continent_from_address(address_dict):

	"""
	
	Takes address dictionary (from 'get_address_by_location'), returns country

	"""

	# dictionary of continent names:
	continent_name_dict = {
		"AF" : "Africa", 
		"AS" : "Asia", 
		"NA" : "North America", 
		"SA" : "South America", 
		"OC" : "Oceania", 
		"EU" : "Europe"
	}

	# get info from address dict
	address = address_dict["address"]
	country = address["country"]

	# get continent
	country_code = pc.country_name_to_country_alpha2(country, cn_name_format="default")

	continent_abbreviation = pc.country_alpha2_to_continent_code(country_code)
	continent_name = continent_name_dict[continent_abbreviation]

	return [country, continent_name]


if __name__ == "__main__":

	# define your coordinates
	latitude = 36.723
	longitude = 3.188

	# get the address info
	address = get_address_by_location(latitude, longitude)
	# print all returned data
	pprint(address)

	pprint(get_country_continent_from_address(address))