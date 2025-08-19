export async function GET(request: Request) {
  const url = new URL(request.url);
  const lat = url.searchParams.get('lat') || '13.7563';
  const lng = url.searchParams.get('lng') || '100.5018';
  
  const apiKey = process.env.EXPO_PUBLIC_GOOGLE_PLACES_API_KEY;
  
  if (!apiKey) {
    return Response.json({
      success: false,
      error: 'Google Places API key not configured',
      message: 'Please add EXPO_PUBLIC_GOOGLE_PLACES_API_KEY to your .env file'
    }, { status: 400 });
  }

  try {
    const placesUrl = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${lat},${lng}&radius=1000&type=restaurant&key=${apiKey}`;
    
    const response = await fetch(placesUrl);
    const data = await response.json();
    
    if (data.status === 'OK') {
      return Response.json({
        success: true,
        message: 'Google Places API is working correctly!',
        resultsCount: data.results?.length || 0,
        samplePlace: data.results?.[0]?.name || 'No places found',
        status: data.status
      });
    } else if (data.status === 'REQUEST_DENIED') {
      return Response.json({
        success: false,
        error: 'API Key Invalid or Restricted',
        message: 'Your API key is either invalid or has restrictions that prevent this request',
        status: data.status,
        errorMessage: data.error_message
      }, { status: 403 });
    } else {
      return Response.json({
        success: false,
        error: `Google Places API Error: ${data.status}`,
        message: data.error_message || 'Unknown error occurred',
        status: data.status
      }, { status: 400 });
    }
  } catch (error) {
    return Response.json({
      success: false,
      error: 'Network Error',
      message: 'Failed to connect to Google Places API',
      details: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 });
  }
}