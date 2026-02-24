
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(NULLIF(p.Body, ''), 'No content available') AS SafeBody
    FROM 
        Posts p
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '2 years'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        CASE 
            WHEN u.Reputation > 1000 THEN 'High Rep'
            WHEN u.Reputation BETWEEN 501 AND 1000 THEN 'Medium Rep'
            ELSE 'Low Rep'
        END AS ReputationCategory,
        u.Location,
        COALESCE(u.AboutMe, 'No description') AS AboutUser
    FROM 
        Users u
    WHERE 
        u.Reputation >= 0
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownvoteCount
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
CombinedStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ur.ReputationCategory,
        ur.Location,
        ur.AboutUser,
        COALESCE(pvc.UpvoteCount, 0) AS UpvoteCount,
        COALESCE(pvc.DownvoteCount, 0) AS DownvoteCount,
        rp.SafeBody,
        CASE 
            WHEN rp.Score = 0 THEN 'No Score'
            WHEN rp.Score > 0 THEN 'Positive'
            ELSE 'Negative'
        END AS ScoreCategory,
        CASE 
            WHEN rp.ViewCount > 1000 THEN 'High Traffic'
            ELSE 'Regular Traffic'
        END AS TrafficCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN 
        PostVoteCounts pvc ON rp.PostId = pvc.PostId
)
SELECT 
    cs.PostId,
    cs.Title,
    cs.CreationDate,
    cs.Score,
    cs.ViewCount,
    cs.DisplayName,
    cs.Reputation,
    cs.ReputationCategory,
    cs.Location,
    cs.AboutUser,
    cs.UpvoteCount,
    cs.DownvoteCount,
    cs.SafeBody,
    cs.ScoreCategory,
    cs.TrafficCategory
FROM 
    CombinedStats cs
WHERE 
    cs.ReputationCategory = 'High Rep' 
    OR (cs.ReputationCategory = 'Medium Rep' AND cs.Score > 0)
ORDER BY 
    cs.CreationDate DESC, cs.UpvoteCount DESC
LIMIT 20 OFFSET 10;
