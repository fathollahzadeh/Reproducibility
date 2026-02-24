
WITH LatestPostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS LatestRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATE '2024-10-01' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate
),
TopUser AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        CASE 
            WHEN COUNT(DISTINCT p.Id) > 10 THEN 'Active Contributor' 
            WHEN SUM(b.Class) > 0 THEN 'Badge Holder'
            ELSE 'Novice'
        END AS UserCategory
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 0
),
HighlyRatedPosts AS (
    SELECT 
        lp.PostId,
        lp.Title,
        lp.UpVoteCount,
        lp.DownVoteCount,
        nt.UserId,
        nt.UserCategory
    FROM 
        LatestPostStats lp
    INNER JOIN 
        TopUser nt ON lp.OwnerUserId = nt.UserId
    WHERE 
        lp.UpVoteCount - lp.DownVoteCount > 10
    ORDER BY 
        lp.UpVoteCount DESC
),
PostWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ARRAY_AGG(t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(p.Tags, '>')) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON tag = t.TagName
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title
),
FinalOutput AS (
    SELECT 
        h.Title,
        h.UpVoteCount,
        h.DownVoteCount,
        t.Tags,
        u.DisplayName AS Owner,
        u.Reputation AS Reputation,
        h.UserCategory
    FROM 
        HighlyRatedPosts h
    JOIN 
        PostWithTags t ON h.PostId = t.PostId
    JOIN 
        Users u ON h.UserId = u.Id
    WHERE 
        u.Reputation IS NOT NULL
)
SELECT 
    *
FROM 
    FinalOutput
ORDER BY 
    UpVoteCount DESC
LIMIT 10;
