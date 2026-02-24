WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        STRING_AGG(t.TagName, ', ') AS Tags,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Body,
        RP.CreationDate,
        RP.ViewCount,
        RP.Tags,
        RP.CommentCount,
        RP.UpVotes,
        RP.DownVotes,
        RP.RankByViews
    FROM 
        RankedPosts RP
    WHERE 
        RP.RankByViews <= 10  
),
PostEdits AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name || ': ' || ph.Text, '; ') AS Edits,
        COUNT(ph.Id) AS EditCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.PostId IN (SELECT PostId FROM TopPosts)
    GROUP BY 
        ph.PostId
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.Body,
    TP.CreationDate,
    TP.ViewCount,
    TP.Tags,
    TP.CommentCount,
    TP.UpVotes,
    TP.DownVotes,
    PE.Edits,
    PE.EditCount
FROM 
    TopPosts TP
LEFT JOIN 
    PostEdits PE ON TP.PostId = PE.PostId
ORDER BY 
    TP.ViewCount DESC;