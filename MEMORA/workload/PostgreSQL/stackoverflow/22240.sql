
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(b.Class, 0) AS BadgeClass
    FROM 
        Users u
    LEFT JOIN 
        (SELECT UserId, MAX(Class) AS Class FROM Badges GROUP BY UserId) b ON u.Id = b.UserId
),

FinalReport AS (
    SELECT 
        p.PostId,
        p.Title,
        p.CreationDate,
        p.CommentCount,
        p.UpVotes,
        p.DownVotes,
        u.Reputation,
        u.BadgeClass,
        CASE 
            WHEN p.CommentCount = 0 THEN 'No comments yet.'
            WHEN p.UpVotes - p.DownVotes > 10 THEN 'Popular post!'
            ELSE 'Requires more engagement.'
        END AS EngagementStatus,
        CASE 
            WHEN u.Reputation >= 1000 THEN 'High Reputation'
            ELSE 'Regular User'
        END AS UserStatus
    FROM 
        RankedPosts p
    JOIN 
        UserReputation u ON p.OwnerUserId = u.UserId
    WHERE 
        p.UserPostRank = 1
    ORDER BY 
        p.CreationDate DESC
)

SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.CommentCount,
    fr.UpVotes,
    fr.DownVotes,
    fr.Reputation,
    fr.BadgeClass,
    fr.EngagementStatus,
    fr.UserStatus
FROM 
    FinalReport fr
WHERE 
    fr.CommentCount IS NOT NULL
    AND (fr.UpVotes + fr.DownVotes) > 5
UNION ALL
SELECT 
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    'No valid posts found' AS EngagementStatus,
    'Check back later' AS UserStatus
WHERE 
    NOT EXISTS (SELECT 1 FROM FinalReport)
ORDER BY 
    CreationDate DESC NULLS LAST;
