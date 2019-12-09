


I believe that the best lesson which an engineer can learn is making good trade-offs. And that is exactly why I chose to work on Spiking Neural Networks - a trade-off between accuracy and power efficiency. 

The conventional convNet has high accuracy but also very computationally intensive -- which is why it can't be ran on common smartphones or watches in 2019. However, SNN provides a power solution: it consumes 100-1000 times less energy, hence, much faster than a CNN, just like the human brain. 

The Neurons in the SNN is one of the closest things to what's inside the brain. 

Imagine 2 neurons: pre-synaptic and post-synaptic connected together by a synapse with a certain weight. 

When the pre-synaptic neuron fires, charges or energy accumulates at the post-synaptic neuron. 

When the membrain energy threshold of the post-synaptic neuron is crossed, the neuron fires a spike towards the next neuron it is connected to. 

Okay, now you may ask: "How does it learn?" The quick answer is STDP - Spike Timing Dependent Plasticity: The weight of the synapse will increase if 2 neurons "spike together" and decrease otherwise. 

This weight number determines the probability of the pre-synaptic neuron to fire. Hence, in a trained network, a certain group of neurons will fire in a certain pattern when a stimulus is introduced at the input layer -- the same principle our brain use in learning. 

Therefore, in our speech recognition application, the MFCC is presented as stimulus at the input layer, from which spikes will travel to a hidden layer with a 1 by 3 kernel. 

The spikes from this hidden layer is then fed into a "max pooling" layer, which takes the spikes pattern from the pre-synaptic neuron that has the highest firing frequency and passes on as output. 

This output is then fed into a K-Means clustering algorithm with k=2. 

The accuracy of our system come at around 90%. 

Although this unsupervised learning machine is in its infant stage with a lot of room for improvements, this result brings hope that there exists a type of neural network which can achieve the efficiency of the human brain. 

Futureworks includes: making snn more stable, having the neurons only fire when it absolutely needed to, implementing lossless input signal encoding technique, or better max-pooling techniques, and introducing a hint network which can allow the main network to be more robust to outliers and converges faster. 

Finally, this network will be tested on neuromorphic devices for further analysis to optimize energy consumption.