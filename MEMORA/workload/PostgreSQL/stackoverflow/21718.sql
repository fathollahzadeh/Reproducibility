
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),

CloseAndEditHistory AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CASE WHEN pt.Name = 'Post Closed' THEN ph.Comment ELSE NULL END, '; ') AS CloseReasons,
        STRING_AGG(CASE WHEN pt.Name LIKE 'Edit %' THEN ph.Text ELSE NULL END, '; ') AS EditHistory,
        MAX(ph.CreationDate) AS LastActivityDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY 
        ph.PostId
),

UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvotesGiven,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvotesGiven
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    uch.UserId,
    uch.DisplayName,
    uch.Reputation,
    uch.UpvotesGiven,
    uch.DownvotesGiven,
    cah.CloseReasons,
    cah.EditHistory,
    cah.LastActivityDate
FROM 
    RankedPosts rp
LEFT JOIN 
    Comments c ON c.PostId = rp.PostId
LEFT JOIN 
    UserReputation uch ON c.UserId = uch.UserId
LEFT JOIN 
    CloseAndEditHistory cah ON rp.PostId = cah.PostId
WHERE 
    (rp.Rank <= 5 OR rp.Score > 100)
AND 
    (uch.Reputation <= 1000 OR uch.UpvotesGiven > uch.DownvotesGiven)
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC,
    rp.CreationDate DESC;
