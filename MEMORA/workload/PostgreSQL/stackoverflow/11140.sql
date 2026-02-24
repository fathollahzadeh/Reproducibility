WITH BenchmarkData AS (
    SELECT 
        p.Id AS PostId,
        p.CreationDate,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COUNT(b.Id) AS BadgeCount,
        u.Reputation AS UserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        p.Id, p.CreationDate, pt.Name, u.Reputation
)
SELECT 
    PostType,
    AVG(UserReputation) AS AvgUserReputation,
    AVG(CommentCount) AS AvgCommentCount,
    AVG(VoteCount) AS AvgVoteCount,
    AVG(BadgeCount) AS AvgBadgeCount,
    COUNT(PostId) AS PostCount
FROM 
    BenchmarkData
GROUP BY 
    PostType
ORDER BY 
    PostCount DESC;
