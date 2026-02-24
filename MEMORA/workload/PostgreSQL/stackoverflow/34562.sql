
WITH RecursivePostHistory AS (
    SELECT 
        p.Id AS PostId, 
        ph.CreationDate AS EditDate, 
        ph.Comment AS EditComment, 
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (2, 4, 6) 
),
BadgesSummary AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND p.ClosedDate IS NULL 
),
AggregatedVotes AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN VoteTypeId = 6 THEN 1 ELSE 0 END) AS CloseVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    COALESCE(avs.UpVotes, 0) AS TotalUpVotes,
    COALESCE(avs.DownVotes, 0) AS TotalDownVotes,
    COALESCE(avs.CloseVotes, 0) AS TotalCloseVotes,
    COUNT(DISTINCT c.UserId) AS CommentersCount,
    b.BadgeCount,
    b.BadgeNames,
    MAX(rph.EditDate) AS LastEditDate,
    MAX(rph.EditComment) AS LastEditComment
FROM 
    TopPosts tp
LEFT JOIN 
    AggregatedVotes avs ON tp.Id = avs.PostId
LEFT JOIN 
    Comments c ON tp.Id = c.PostId
LEFT JOIN 
    BadgesSummary b ON c.UserId = b.UserId
LEFT JOIN 
    RecursivePostHistory rph ON tp.Id = rph.PostId AND rph.rn = 1 
WHERE 
    (b.BadgeCount IS NULL OR b.BadgeCount > 0) 
GROUP BY 
    tp.Title, tp.Score, tp.ViewCount, avs.UpVotes, avs.DownVotes, avs.CloseVotes, b.BadgeCount, b.BadgeNames
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
