from flask import Flask, jsonify, request

app = Flask(__name__)

# Sample data for real-life applications of each subject
subject_data = {
    'Math': [
        'Cryptography algorithms (like RSA) used in secure internet communications',
        'Statistical analysis in weather forecasting and market prediction',
        'Algorithm optimization in computer science for faster processing',
        'Geometry in architectural design and urban planning',
        'Probability theory in insurance risk assessment'
    ],
    'Science': [
        'Chemistry in pharmaceuticals development',
        'Physics in renewable energy technologies',
        'Biology in genetic engineering and medicine',
        'Environmental monitoring and climate studies',
        'Materials science for advanced manufacturing'
    ],
    'Physics': [
        'Electromagnetic waves in wireless communication (WiFi, cell phones)',
        'Nuclear physics in medical imaging (MRI machines)',
        'Thermodynamics in car engine design',
        'Optics in camera and telescope technology',
        'Quantum mechanics in computer chips and lasers'
    ],
    'Chemistry': [
        'Catalysts in petroleum refining and plastic production',
        'Polymers in textile and packaging industries',
        'Electrochemistry in battery technology for electric vehicles',
        'Drug discovery and pharmaceutical synthesis',
        'Food preservation techniques and nutritional chemistry'
    ],
    'Biology': [
        'Microorganisms in fermentation (bread, cheese, beer)',
        'Genetic engineering in agriculture (GM crops)',
        'Immunology in vaccine development',
        'Ecosystem studies for environmental conservation',
        'Neurobiology in understanding mental health treatments'
    ],
    'Geography': [
        'GPS navigation systems and mapping services',
        'Urban planning and city development',
        'Climate change monitoring and prediction',
        'Natural resource management and mining',
        'Transportation logistics and supply chains'
    ],
    'History': [
        'Archaeological methods in modern forensics',
        'Historical analysis in international relations',
        'Museum curation and cultural preservation',
        'Historical linguistics in AI language processing',
        'Legal precedent studies in modern law courts'
    ],
    'Environmental Science': [
        'Renewable energy systems and sustainability studies',
        'Water treatment and pollution control technologies',
        'Conservation biology for species protection',
        'Carbon capture and climate change mitigation',
        'Environmental impact assessment for development projects'
    ],
    'Commerce': [
        'E-commerce platforms and online marketplaces',
        'Financial modeling and stock market analysis',
        'Supply chain management systems',
        'Marketing strategies in digital advertising',
        'International trade and globalization policies'
    ],
    'Economics': [
        'Inflation prediction models for central banks',
        'Cost-benefit analysis in policy making',
        'Market research and consumer behavior studies',
        'Economic forecasting for business planning',
        'Labor market analysis and employment trends'
    ]
}

@app.route('/api/applications/<subject>', methods=['GET'])
def get_applications(subject):
    """Get real-life applications for a specific subject"""
    if subject in subject_data:
        return jsonify({
            'subject': subject,
            'applications': subject_data[subject]
        })
    else:
        return jsonify({'error': 'Subject not found'}), 404

@app.route('/api/subjects', methods=['GET'])
def get_subjects():
    """Get list of available subjects"""
    return jsonify({'subjects': list(subject_data.keys())})

@app.route('/')
def home():
    """Home page with basic information"""
    return jsonify({
        'message': 'Real Life Applications API',
        'endpoints': [
            '/api/subjects - Get available subjects',
            '/api/applications/<subject> - Get applications for specific subject'
        ]
    })

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
