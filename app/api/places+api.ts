export async function GET(request: Request) {
  const url = new URL(request.url);
  const query = url.searchParams.get('query');
  const location = url.searchParams.get('location');
  const radius = url.searchParams.get('radius') || '5000';
  const type = url.searchParams.get('type') || 'restaurant';

  if (!query && !location) {
    return new Response('Query or location parameter is required', {
      status: 400,
      headers: { 'Content-Type': 'text/plain' },
    });
  }

  try {
    // Note: In production, you'd use your Google Places API key
    // For now, we'll return enhanced mock data that simulates real Google Places responses
    const mockPlacesData = await getMockGooglePlacesData(query, location, type);
    
    return Response.json({
      results: mockPlacesData,
      status: 'OK'
    });
  } catch (error) {
    return new Response('Failed to fetch places data', {
      status: 500,
      headers: { 'Content-Type': 'text/plain' },
    });
  }
}

async function getMockGooglePlacesData(query: string | null, location: string | null, type: string) {
  // Enhanced mock data that simulates Google Places API responses
  const bangkokPlaces = [
    {
      place_id: 'ChIJN1t_tDeuEmsRUsoyG83frY4',
      name: 'Sirocco Restaurant',
      formatted_address: '1055 Silom Rd, Bang Rak, Bangkok 10500, Thailand',
      geometry: {
        location: { lat: 13.7217, lng: 100.5154 }
      },
      rating: 4.3,
      price_level: 4,
      types: ['restaurant', 'bar', 'establishment'],
      photos: [{
        photo_reference: 'https://images.pexels.com/photos/1581384/pexels-photo-1581384.jpeg?auto=compress&cs=tinysrgb&w=800&h=600&fit=crop&fm=webp'
      }],
      opening_hours: {
        open_now: true,
        periods: [
          {
            open: { day: 0, time: '1800' },
            close: { day: 0, time: '0100' }
          }
        ]
      },
      business_status: 'OPERATIONAL'
    },
    {
      place_id: 'ChIJrTLr-GyuEmsRBfy61i59si0',
      name: 'Health Land Spa & Massage',
      formatted_address: '120 North Sathorn Rd, Silom, Bang Rak, Bangkok 10500, Thailand',
      geometry: {
        location: { lat: 13.7240, lng: 100.5280 }
      },
      rating: 4.6,
      price_level: 2,
      types: ['spa', 'health', 'establishment'],
      photos: [{
        photo_reference: 'https://images.pexels.com/photos/3757942/pexels-photo-3757942.jpeg?auto=compress&cs=tinysrgb&w=800&h=600&fit=crop&fm=webp'
      }],
      opening_hours: {
        open_now: true,
        periods: [
          {
            open: { day: 0, time: '0900' },
            close: { day: 0, time: '2400' }
          }
        ]
      },
      business_status: 'OPERATIONAL'
    },
    {
      place_id: 'ChIJ39UebIauEmsRSdZy5lIhOWs',
      name: 'Chatuchak Weekend Market',
      formatted_address: '587, 10 Kamphaeng Phet 2 Rd, Chatuchak, Bangkok 10900, Thailand',
      geometry: {
        location: { lat: 13.7998, lng: 100.5501 }
      },
      rating: 4.1,
      price_level: 1,
      types: ['tourist_attraction', 'establishment'],
      photos: [{
        photo_reference: 'https://images.pexels.com/photos/1267320/pexels-photo-1267320.jpeg?auto=compress&cs=tinysrgb&w=800&h=600&fit=crop&fm=webp'
      }],
      opening_hours: {
        open_now: false,
        periods: [
          {
            open: { day: 6, time: '0600' },
            close: { day: 6, time: '1800' }
          }
        ]
      },
      business_status: 'OPERATIONAL'
    },
    {
      place_id: 'ChIJBa7CjIauEmsRSKZy5lIhOWs',
      name: 'Wat Pho Thai Traditional Massage School',
      formatted_address: '2 Sanamchai Road, Grand Palace Subdistrict, Pranakorn District, Bangkok 10200, Thailand',
      geometry: {
        location: { lat: 13.7465, lng: 100.4927 }
      },
      rating: 4.8,
      price_level: 2,
      types: ['spa', 'school', 'establishment'],
      photos: [{
        photo_reference: 'https://images.pexels.com/photos/3865676/pexels-photo-3865676.jpeg?auto=compress&cs=tinysrgb&w=800&h=600&fit=crop&fm=webp'
      }],
      opening_hours: {
        open_now: true,
        periods: [
          {
            open: { day: 0, time: '0800' },
            close: { day: 0, time: '1700' }
          }
        ]
      },
      business_status: 'OPERATIONAL'
    },
    {
      place_id: 'ChIJCa7CjIauEmsRSKZy5lIhOWs',
      name: 'Blue Elephant Restaurant',
      formatted_address: '233 South Sathorn Rd, Yan Nawa, Sathorn, Bangkok 10120, Thailand',
      geometry: {
        location: { lat: 13.7180, lng: 100.5310 }
      },
      rating: 4.4,
      price_level: 3,
      types: ['restaurant', 'establishment'],
      photos: [{
        photo_reference: 'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=800&h=600&fit=crop&fm=webp'
      }],
      opening_hours: {
        open_now: true,
        periods: [
          {
            open: { day: 0, time: '1130' },
            close: { day: 0, time: '1430' }
          }
        ]
      },
      business_status: 'OPERATIONAL'
    },
    {
      place_id: 'ChIJDa7CjIauEmsRSKZy5lIhOWs',
      name: 'Divana Virtue Spa',
      formatted_address: '7 Sukhumvit Soi 25, Khlong Toei Nuea, Watthana, Bangkok 10110, Thailand',
      geometry: {
        location: { lat: 13.7390, lng: 100.5610 }
      },
      rating: 4.7,
      price_level: 3,
      types: ['spa', 'beauty_salon', 'establishment'],
      photos: [{
        photo_reference: 'https://images.pexels.com/photos/3865711/pexels-photo-3865711.jpeg?auto=compress&cs=tinysrgb&w=800&h=600&fit=crop&fm=webp'
      }],
      opening_hours: {
        open_now: true,
        periods: [
          {
            open: { day: 0, time: '1000' },
            close: { day: 0, time: '2200' }
          }
        ]
      },
      business_status: 'OPERATIONAL'
    }
  ];

  // Filter based on type if specified
  let filteredPlaces = bangkokPlaces;
  if (type && type !== 'establishment') {
    filteredPlaces = bangkokPlaces.filter(place => 
      place.types.includes(type) || 
      (type === 'spa' && (place.types.includes('spa') || place.types.includes('health'))) ||
      (type === 'restaurant' && place.types.includes('restaurant'))
    );
  }

  // Filter based on query if specified
  if (query) {
    filteredPlaces = filteredPlaces.filter(place =>
      place.name.toLowerCase().includes(query.toLowerCase()) ||
      place.formatted_address.toLowerCase().includes(query.toLowerCase())
    );
  }

  return filteredPlaces;
}