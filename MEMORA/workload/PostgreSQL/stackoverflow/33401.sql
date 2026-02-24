WITH RecursiveTagStats AS (
    SELECT 
        Tags.Id AS TagId,
        Tags.TagName,
        COUNT(Posts.Id) AS PostCount,
        SUM(COALESCE(Posts.ViewCount, 0)) AS TotalViews,
        ROW_NUMBER() OVER (ORDER BY COUNT(Posts.Id) DESC) AS TagRanking
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Posts.Tags LIKE '%' || Tags.TagName || '%'
    GROUP BY 
        Tags.Id, Tags.TagName
),
UserReputation AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        SUM(COALESCE(Posts.Score, 0)) AS TotalScore,
        COUNT(DISTINCT Posts.Id) AS TotalPosts,
        COUNT(distinct Badges.Id) AS TotalBadges
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Badges ON Users.Id = Badges.UserId
    GROUP BY 
        Users.Id, Users.DisplayName
),
PostInteractions AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Users.DisplayName AS Author,
        COALESCE(Votes.TotalVotes, 0) AS VoteCount,
        COALESCE(Comments.TotalComments, 0) AS CommentCount
    FROM 
        Posts
    LEFT JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS TotalVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) AS Votes ON Posts.Id = Votes.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS TotalComments
        FROM 
            Comments
        GROUP BY 
            PostId
    ) AS Comments ON Posts.Id = Comments.PostId
)
SELECT 
    UserReputation.DisplayName AS User,
    UserReputation.TotalScore,
    UserReputation.TotalPosts,
    UserReputation.TotalBadges,
    RecursiveTagStats.TagName,
    RecursiveTagStats.PostCount,
    RecursiveTagStats.TotalViews,
    PostInteractions.Title,
    PostInteractions.VoteCount,
    PostInteractions.CommentCount
FROM 
    UserReputation
JOIN 
    RecursiveTagStats ON UserReputation.TotalPosts > 0 
LEFT JOIN 
    PostInteractions ON PostInteractions.Author = UserReputation.DisplayName
WHERE 
    RecursiveTagStats.PostCount > 10 
ORDER BY 
    UserReputation.TotalScore DESC, 
    RecursiveTagStats.TotalViews DESC
FETCH FIRST 10 ROWS ONLY;