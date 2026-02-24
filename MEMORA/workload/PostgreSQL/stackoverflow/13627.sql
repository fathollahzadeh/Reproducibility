
WITH Benchmark AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.Reputation AS UserReputation,
        COUNT(v.Id) AS VoteCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, u.Reputation
)
SELECT 
    AVG(UserReputation) AS AverageUserReputation,
    AVG(Score) AS AverageScore,
    AVG(ViewCount) AS AverageViewCount,
    SUM(VoteCount) AS TotalVotes,
    SUM(CommentCount) AS TotalComments,
    SUM(BadgeCount) AS TotalBadges
FROM 
    Benchmark;
