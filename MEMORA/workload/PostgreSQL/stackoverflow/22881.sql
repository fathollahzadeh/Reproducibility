WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score IS NOT NULL AND 
        p.ViewCount > 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        (SELECT COUNT(DISTINCT b.Id) FROM Badges b WHERE b.UserId = u.Id) AS BadgeCount
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId, 
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypeNames,
        MAX(ph.CreationDate) AS LastEdited
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName AS Author,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    COALESCE(up.Reputation, 0) AS AuthorReputation,
    COALESCE(up.BadgeCount, 0) AS AuthorBadges,
    pHd.HistoryTypeNames,
    pHd.LastEdited,
    COUNT(DISTINCT c.Id) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotes
FROM 
    RankedPosts rp
JOIN 
    Posts p ON rp.PostId = p.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserReputation up ON u.Id = up.UserId
LEFT JOIN 
    PostHistoryDetails pHd ON p.Id = pHd.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    rp.Rank <= 3 
GROUP BY 
    u.DisplayName, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, 
    up.Reputation, up.BadgeCount, pHd.HistoryTypeNames, pHd.LastEdited, p.Id
ORDER BY 
    p.Score DESC, p.ViewCount DESC;