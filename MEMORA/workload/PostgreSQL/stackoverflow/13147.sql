WITH PostStatistics AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        Posts.Score,
        Posts.ViewCount,
        COALESCE(Users.DisplayName, 'Community User') AS Owner,
        COUNT(Comments.Id) AS TotalComments,
        COUNT(CASE WHEN Votes.VoteTypeId = 2 THEN 1 END) AS TotalUpVotes,
        COUNT(CASE WHEN Votes.VoteTypeId = 3 THEN 1 END) AS TotalDownVotes
    FROM 
        Posts
    LEFT JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Posts.Id, Posts.Title, Posts.CreationDate, Posts.Score, Posts.ViewCount, Users.DisplayName
)

SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    Owner,
    TotalComments,
    TotalUpVotes,
    TotalDownVotes
FROM 
    PostStatistics
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 100;