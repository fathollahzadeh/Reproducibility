
WITH UserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        SUM(COALESCE(p.CommentCount, 0)) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        pp.DisplayName AS OwnerDisplayName,
        pt.Name AS PostType,
        p.Score,
        p.ViewCount,
        p.CommentCount,
        p.AnswerCount,
        p.FavoriteCount,
        p.ClosedDate,
        p.LastEditDate,
        COALESCE(ph.RevisionCount, 0) AS RevisionCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Users pp ON p.OwnerUserId = pp.Id
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS RevisionCount
        FROM 
            PostHistory
        GROUP BY 
            PostId
    ) ph ON p.Id = ph.PostId
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.QuestionCount,
    u.AnswerCount,
    u.TotalScore,
    AVG(p.Score) AS AvgPostScore,
    AVG(p.ViewCount) AS AvgViewCount,
    AVG(p.AnswerCount) AS AvgAnswerCount,
    AVG(p.CommentCount) AS AvgCommentCount,
    AVG(p.FavoriteCount) AS AvgFavoriteCount,
    SUM(p.RevisionCount) AS TotalRevisions
FROM 
    UserPosts u
LEFT JOIN 
    PostStatistics p ON u.UserId = p.OwnerUserId
GROUP BY 
    u.UserId, u.DisplayName, u.TotalPosts, u.QuestionCount, u.AnswerCount, u.TotalScore
ORDER BY 
    u.TotalPosts DESC
LIMIT 10;
