WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.PostTypeId, p.CreationDate
),
AverageStats AS (
    SELECT 
        PostTypeId,
        AVG(CommentCount) AS AvgCommentCount,
        AVG(VoteCount) AS AvgVoteCount,
        AVG(UpVotes) AS AvgUpVotes,
        AVG(DownVotes) AS AvgDownVotes,
        AVG(BadgeCount) AS AvgBadgeCount
    FROM 
        PostStats
    GROUP BY 
        PostTypeId
)

SELECT 
    pt.Name AS PostType,
    AVG(AvgCommentCount) AS AvgCommentCount,
    AVG(AvgVoteCount) AS AvgVoteCount,
    AVG(AvgUpVotes) AS AvgUpVotes,
    AVG(AvgDownVotes) AS AvgDownVotes,
    AVG(AvgBadgeCount) AS AvgBadgeCount
FROM 
    AverageStats as avg
JOIN 
    PostTypes pt ON avg.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    pt.Name;