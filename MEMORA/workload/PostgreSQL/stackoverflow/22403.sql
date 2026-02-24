WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUBSTRING(p.Body, 1, 100) AS PreviewBody,
        ARRAY_LENGTH(string_to_array(p.Tags, ','), 1) AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),

UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(b.Id) AS BadgeCount,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 1) AS QuestionCount,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId IN (2, 3)) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),

HighRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        um.UserId,
        um.Reputation,
        um.TotalBounty,
        um.BadgeCount,
        um.QuestionCount,
        um.AnswerCount
    FROM 
        RankedPosts rp
    JOIN 
        UserMetrics um ON rp.RankByScore = 1 AND rp.PostId IN (
            SELECT PostId 
            FROM Votes 
            WHERE VoteTypeId = 2 
            GROUP BY PostId
            HAVING COUNT(*) > 5 
        )
    WHERE 
        rp.Score IS NOT NULL
)

SELECT 
    h.Title,
    h.CreationDate,
    h.Score,
    h.UserId,
    h.Reputation,
    h.TotalBounty,
    h.BadgeCount,
    h.QuestionCount,
    h.AnswerCount,
    CASE 
        WHEN h.Score > 100 THEN 'Highly Engaging'
        WHEN h.Score BETWEEN 50 AND 100 THEN 'Moderately Engaging'
        ELSE 'Low Engagement'
    END AS EngagementLevel,
    CASE 
        WHEN h.TotalBounty = 0 THEN 'No Bounty Offered'
        ELSE 'Bounty Offered'
    END AS BountyStatus
FROM 
    HighRankedPosts h
WHERE 
    h.Reputation > 500
ORDER BY 
    h.Score DESC, 
    h.Reputation DESC
FETCH FIRST 10 ROWS ONLY;