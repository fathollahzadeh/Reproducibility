
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.Score > 0 AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
), PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        rp.CommentCount,
        rp.OwnerDisplayName,
        ph.Comment AS LastEditComment,
        ph.CreationDate AS LastEditDate,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS TotalComments,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS TotalUpVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistory ph ON rp.PostId = ph.PostId AND ph.PostHistoryTypeId IN (4, 5) 
    WHERE 
        rp.Rank <= 10
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.AnswerCount,
    pd.CommentCount,
    pd.OwnerDisplayName,
    pd.LastEditComment,
    pd.LastEditDate,
    pd.TotalComments,
    pd.TotalUpVotes,
    COALESCE(pt.Name, 'Unknown') AS PostTypeName,
    COALESCE(bt.Name, 'None') AS BestBadge,
    COALESCE(lt.Name, 'None') AS LinkType
FROM 
    PostDetails pd
LEFT JOIN 
    PostTypes pt ON EXISTS (SELECT 1 FROM Posts p WHERE p.Id = pd.PostId AND p.PostTypeId = pt.Id)
LEFT JOIN 
    Badges bt ON bt.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = pd.PostId) AND bt.Class = 1 
LEFT JOIN 
    PostLinks pl ON pl.PostId = pd.PostId
LEFT JOIN 
    LinkTypes lt ON pl.LinkTypeId = lt.Id
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
