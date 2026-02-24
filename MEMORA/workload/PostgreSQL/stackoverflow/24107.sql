WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes, 
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(c.Id) DESC) AS RankComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        RankComments <= 5 
),
PostStats AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CommentCount,
        tp.UpVotes,
        tp.DownVotes,
        (CASE 
            WHEN tp.UpVotes + tp.DownVotes = 0 THEN NULL 
            ELSE ROUND((tp.UpVotes::decimal / NULLIF(tp.UpVotes + tp.DownVotes, 0)) * 100, 2) 
         END) AS ApprovalRate
    FROM 
        TopPosts tp
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.ApprovalRate,
    COALESCE(pt.Name, 'No Post Type') AS PostTypeName,
    (SELECT STRING_AGG(t.TagName, ', ') 
     FROM Tags t 
     JOIN Posts p2 ON p2.Tags LIKE '%' || t.TagName || '%' 
     WHERE p2.Id = ps.PostId) AS Tags,
    (SELECT COUNT(*) 
     FROM PostHistory ph 
     WHERE ph.PostId = ps.PostId AND ph.PostHistoryTypeId IN (10, 11)
    ) AS CloseReopenHistory,
    (CASE 
        WHEN EXISTS (SELECT 1 
                     FROM Votes v 
                     WHERE v.PostId = ps.PostId AND v.VoteTypeId = 1) 
        THEN 'Accepted by Originator' 
        ELSE 'Not Accepted'
     END) AS AcceptanceStatus
FROM 
    PostStats ps
LEFT JOIN 
    PostTypes pt ON (ps.PostId = pt.Id)
ORDER BY 
    ps.CommentCount DESC, ApprovalRate DESC;