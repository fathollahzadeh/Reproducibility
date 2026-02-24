
WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        Id, 
        Reputation
    FROM 
        Users
    WHERE 
        Reputation > 1000
    UNION ALL
    SELECT 
        u.Id, 
        ur.Reputation + u.Reputation
    FROM 
        Users u
    INNER JOIN 
        UserReputationCTE ur ON u.Id = ur.Id
    WHERE 
        u.Reputation IS NOT NULL
),
VoteStats AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PopularTags AS (
    SELECT 
        LOWER(TRIM(REGEXP_REPLACE(Tags, '<.*?>', ''))) AS CleanedTag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        LOWER(TRIM(REGEXP_REPLACE(Tags, '<.*?>', '')))
    HAVING 
        COUNT(*) > 50
),
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
FinalPostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        us.Reputation AS UserReputation,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        bt.BadgeCount,
        pt.TagCount
    FROM 
        Posts p
    LEFT JOIN 
        Users us ON p.OwnerUserId = us.Id
    LEFT JOIN 
        VoteStats vs ON p.Id = vs.PostId
    LEFT JOIN 
        UserBadges bt ON us.Id = bt.UserId
    LEFT JOIN 
        PopularTags pt ON pt.CleanedTag IN (SELECT UNNEST(string_to_array(p.Tags, '>')))
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
)
SELECT 
    fps.PostId,
    fps.Title,
    fps.CreationDate,
    fps.UserReputation,
    fps.UpVotes,
    fps.DownVotes,
    fps.BadgeCount,
    fps.TagCount,
    CASE 
        WHEN fps.UserReputation IS NULL THEN 'No Reputation'
        WHEN fps.UserReputation > 5000 THEN 'Expert'
        WHEN fps.UserReputation > 1000 THEN 'Experienced'
        ELSE 'Novice'
    END AS ReputationLevel
FROM 
    FinalPostStats fps
ORDER BY 
    fps.UpVotes DESC, 
    fps.DownVotes,
    fps.CreationDate DESC
LIMIT 50;
