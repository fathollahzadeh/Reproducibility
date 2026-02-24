
WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(u.Reputation) AS AverageReputation,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags ILIKE CONCAT('%', t.TagName, '%')
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        t.TagName
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
),
BenchmarkResults AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.AverageReputation,
        ts.GoldBadges,
        ts.SilverBadges,
        ts.BronzeBadges,
        SUM(pe.CommentCount) AS TotalComments,
        SUM(pe.UpVoteCount) AS TotalUpVotes
    FROM 
        TagStatistics ts
    JOIN 
        PostEngagement pe ON ts.PostCount > 0
    GROUP BY 
        ts.TagName, ts.PostCount, ts.AverageReputation, ts.GoldBadges, ts.SilverBadges, ts.BronzeBadges
)
SELECT 
    BenchmarkResults.*,
    CASE 
        WHEN AverageReputation > 1000 THEN 'Experienced'
        WHEN AverageReputation BETWEEN 500 AND 1000 THEN 'Intermediate'
        ELSE 'Novice'
    END AS ReputationLevel,
    CASE 
        WHEN TotalUpVotes > TotalComments THEN 'High Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    BenchmarkResults
ORDER BY 
    PostCount DESC, AverageReputation DESC;
