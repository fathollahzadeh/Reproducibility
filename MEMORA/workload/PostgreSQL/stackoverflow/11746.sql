
WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(COALESCE(p.AnswerCount, 0)) AS AvgAnswers,
        AVG(COALESCE(p.CommentCount, 0)) AS AvgComments,
        AVG(COALESCE(p.FavoriteCount, 0)) AS AvgFavorites,
        AVG(COALESCE(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.CreationDate)), 0)) AS AvgPostAgeSeconds
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        p.PostTypeId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
        LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
)
SELECT 
    pst.PostTypeId,
    pst.TotalPosts,
    pst.TotalViews,
    pst.TotalScore,
    pst.AvgAnswers,
    pst.AvgComments,
    pst.AvgFavorites,
    uact.UserId,
    uact.TotalPosts AS UserTotalPosts,
    uact.TotalBounty,
    uact.TotalUpVotes,
    uact.TotalDownVotes
FROM 
    PostStats pst
    LEFT JOIN UserActivity uact ON uact.TotalPosts > 0 
ORDER BY 
    pst.PostTypeId;
