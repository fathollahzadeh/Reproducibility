WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),
OwnerReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT r.PostId) AS RankedPostCount
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts r ON u.Id = r.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
TopOwners AS (
    SELECT 
        UserId,
        Reputation,
        RankedPostCount,
        RANK() OVER (ORDER BY Reputation DESC, RankedPostCount DESC) AS OwnerRank
    FROM 
        OwnerReputation
)
SELECT 
    o.UserId, 
    o.Reputation, 
    o.RankedPostCount, 
    p.Title,
    COALESCE(STRING_AGG(t.TagName, ', '), 'No Tags') AS Tags,
    COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
    COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
FROM 
    TopOwners o
JOIN 
    Posts p ON o.UserId = p.OwnerUserId
LEFT JOIN 
    Tags t ON POSITION(t.TagName IN p.Tags) > 0
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    o.OwnerRank <= 5
GROUP BY 
    o.UserId, o.Reputation, o.RankedPostCount, p.Title
ORDER BY 
    o.Reputation DESC, UpVotes DESC NULLS LAST
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;