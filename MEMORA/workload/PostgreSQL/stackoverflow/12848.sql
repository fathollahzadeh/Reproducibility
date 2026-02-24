WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
AverageStatistics AS (
    SELECT 
        AVG(CommentCount) AS AvgCommentCount,
        AVG(VoteCount) AS AvgVoteCount,
        AVG(UpVoteCount) AS AvgUpVoteCount,
        AVG(DownVoteCount) AS AvgDownVoteCount,
        AVG(BadgeCount) AS AvgBadgeCount
    FROM 
        PostStatistics
)
SELECT 
    ps.*,
    avgStats.*
FROM 
    PostStatistics ps,
    AverageStatistics avgStats
ORDER BY 
    ps.CommentCount DESC, ps.VoteCount DESC;