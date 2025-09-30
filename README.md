# Jenkins Scripts

### Simple scripts for simplifying Jenkins pipelines

This has been created for use with Evolution X Jenkins Server, however can be easily adapted to any other ROMs.

---

To get started:
 - Clone this repository into a globally accessible location (e.g. /media/sauces/scripts)
 - Set the Jenkins step to run a shell calling the script

I've included an [example pipeline](vars/zillions.groovy) to show how this can be used.
Actually, this example is the one I use in prod.

You can see how we upload our builds to an S3-Compatible Bucket for increased worldwide download speeds.

---

### FAQ

 Q. Why use so many different steps?
 - So I can see exactly where an issue with a build job lies.  If it fails on the 'Build ROM' step, I know there's a chance it's just an issue with trees somewhere.  Otherwise it's an issue for myself to look into why something's gone wrong.  
 - It also helps to restart a job from a specific step if it gets interrupted for whatever reason.

 Q. Do we need to use an S3 bucket?
 - Not at all, that's just the implementation we're using.  You're free to switch out to wherever else you may be hosting releases.