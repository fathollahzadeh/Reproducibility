WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVotes,
        RANK() OVER (ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
PostWithBadge AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.UpVotes,
        rp.DownVotes,
        b.Name AS BadgeName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId) AND b.Class = 1 
    WHERE 
        rp.PostRank <= 10 
),
PostHistoryInfo AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(ph.Comment, '; ') AS EditComments,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) 
    GROUP BY 
        p.Id
)
SELECT 
    pw.PostId,
    pw.Title,
    pw.CreationDate,
    pw.ViewCount,
    pw.UpVotes,
    pw.DownVotes,
    pw.BadgeName,
    COALESCE(phe.EditComments, 'No edits made') AS EditComments,
    phe.LastEditDate
FROM 
    PostWithBadge pw
LEFT JOIN 
    PostHistoryInfo phe ON pw.PostId = phe.PostId
WHERE 
    pw.UpVotes - pw.DownVotes > 5 
ORDER BY 
    pw.CreationDate DESC NULLS LAST
FETCH FIRST 20 ROWS ONLY;