
WITH PostVoteAggregation AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.OwnerUserId
),
UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostDetailWithTags AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(pt.Name, 'Unknown') AS PostType,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, '<>')) AS t(TagName) ON TRUE
    GROUP BY 
        p.Id, pt.Name
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    ub.BadgeCount,
    pdwt.Id AS PostId,
    pdwt.Title,
    pdwt.CreationDate AS PostCreationDate,
    pdwt.ViewCount,
    pdwt.Score,
    p.TotalVotes,
    p.UpVotes,
    p.DownVotes,
    pdwt.PostType,
    pdwt.Tags
FROM 
    Users u
LEFT JOIN 
    UserBadgeCounts ub ON u.Id = ub.UserId
LEFT JOIN 
    PostVoteAggregation p ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostDetailWithTags pdwt ON p.PostId = pdwt.Id
WHERE 
    u.Reputation > 1000 
ORDER BY 
    u.Reputation DESC, 
    pdwt.Score DESC 
LIMIT 100;
