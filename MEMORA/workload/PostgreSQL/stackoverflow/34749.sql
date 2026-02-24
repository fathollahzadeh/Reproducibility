
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
TopComments AS (
    SELECT 
        pc.PostId,
        STRING_AGG(pc.Text, ' | ') AS TopCommentTexts
    FROM 
        (SELECT 
             c.PostId,
             c.Text,
             ROW_NUMBER() OVER (PARTITION BY c.PostId ORDER BY c.CreationDate DESC) AS CommentRank
         FROM 
            Comments c
         WHERE 
            c.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
        ) pc
    WHERE 
        pc.CommentRank <= 3  
    GROUP BY 
        pc.PostId
),
PostHistoryChanges AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '3 months'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        COALESCE(tc.TopCommentTexts, 'No comments') AS TopComments,
        COALESCE(SUM(phc.HistoryCount), 0) AS HistoryChanges
    FROM 
        RankedPosts rp
    LEFT JOIN 
        TopComments tc ON rp.PostId = tc.PostId
    LEFT JOIN 
        PostHistoryChanges phc ON rp.PostId = phc.PostId
    WHERE 
        rp.Rank <= 10  
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.CommentCount, rp.UpVotes, rp.DownVotes, tc.TopCommentTexts
    ORDER BY 
        rp.Score DESC
)

SELECT 
    f.PostId,
    f.Title,
    f.CreationDate,
    f.Score,
    f.ViewCount,
    f.CommentCount,
    f.UpVotes,
    f.DownVotes,
    f.TopComments,
    f.HistoryChanges
FROM 
    FinalResults f
WHERE 
    f.Score IS NOT NULL 
    AND f.ViewCount > 100 
ORDER BY 
    f.ViewCount DESC, f.Score DESC;
