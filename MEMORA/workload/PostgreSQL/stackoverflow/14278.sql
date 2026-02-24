WITH PostsStats AS (
    SELECT 
        PostTypeId,
        COUNT(*) AS PostCount,
        AVG(ViewCount) AS AvgViewCount,
        AVG(Score) AS AvgScore,
        AVG(CommentCount) AS AvgCommentCount,
        AVG(AnswerCount) AS AvgAnswerCount
    FROM 
        Posts
    GROUP BY 
        PostTypeId
), 
UsersStats AS (
    SELECT 
        COUNT(*) AS UserCount,
        AVG(Reputation) AS AvgReputation,
        AVG(Views) AS AvgViews,
        AVG(UpVotes) AS AvgUpVotes,
        AVG(DownVotes) AS AvgDownVotes
    FROM 
        Users
)

SELECT 
    p.PostTypeId,
    p.PostCount,
    p.AvgViewCount,
    p.AvgScore,
    p.AvgCommentCount,
    p.AvgAnswerCount,
    u.UserCount,
    u.AvgReputation,
    u.AvgViews,
    u.AvgUpVotes,
    u.AvgDownVotes
FROM 
    PostsStats p,
    UsersStats u
ORDER BY 
    p.PostTypeId;