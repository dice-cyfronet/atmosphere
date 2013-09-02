App.ApplianceType = DS.Model.extend
  name: DS.attr('string')
  description: DS.attr('string')
  shared: DS.attr('boolean')
  scalable: DS.attr('boolean')
  visibility: DS.attr('string')
  author: DS.belongsTo('user')

  published: (->
    this.get('visibility') == 'published'
  ).property 'visibility'

  author_name: (->
    if this.get('author') == null
      'anonymous'
    else
      this.get('author.login')
  ).property 'author.login'
