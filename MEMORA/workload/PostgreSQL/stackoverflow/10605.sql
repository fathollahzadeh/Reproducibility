WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT ph.Id) AS HistoryCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id 
    WHERE 
        p.CreationDate >= '2023-01-01'  
    GROUP BY 
        p.Id, p.PostTypeId
),
PerformanceBenchmark AS (
    SELECT 
        PostTypeId,
        COUNT(*) AS PostCount,
        SUM(CommentCount) AS TotalComments,
        SUM(VoteCount) AS TotalVotes,
        SUM(BadgeCount) AS TotalBadges,
        SUM(HistoryCount) AS TotalHistories,
        AVG(AvgUserReputation) AS AvgUserReputation
    FROM 
        PostStats
    GROUP BY 
        PostTypeId
)
SELECT 
    pt.Name AS PostType,
    pb.PostCount,
    pb.TotalComments,
    pb.TotalVotes,
    pb.TotalBadges,
    pb.TotalHistories,
    pb.AvgUserReputation
FROM 
    PerformanceBenchmark pb
JOIN 
    PostTypes pt ON pb.PostTypeId = pt.Id
ORDER BY 
    PostCount DESC;