
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        AVG(u.Reputation) AS AverageUserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        ViewRank,
        CommentCount,
        UpVoteCount,
        DownVoteCount,
        AverageUserReputation
    FROM 
        RankedPosts
    WHERE 
        ViewRank <= 10
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS PostHistoryTypes,
        CASE 
            WHEN SUM(CASE WHEN pht.Name = 'Post Closed' THEN 1 ELSE 0 END) > 0 THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    tp.AverageUserReputation,
    ph.LastEditDate,
    ph.PostHistoryTypes,
    ph.PostStatus
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistoryDetails ph ON tp.PostId = ph.PostId
ORDER BY 
    tp.ViewCount DESC, 
    tp.CommentCount DESC;
