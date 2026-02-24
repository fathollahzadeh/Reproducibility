
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        CASE 
            WHEN rp.RankByViews = 1 THEN 'Top'
            WHEN rp.RankByViews <= 5 THEN 'Top 5'
            ELSE 'Other'
        END AS Category
    FROM 
        RankedPosts rp 
    WHERE
        rp.RankByViews <= 5
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE 
            WHEN v.CreationDate < p.CreationDate THEN 1 ELSE 0 
        END) AS VotesBeforeCreation
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    GROUP BY 
        p.Id
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    pa.UpVotes,
    pa.DownVotes,
    pa.TotalVotes,
    pa.VotesBeforeCreation,
    CASE 
        WHEN pa.UpVotes IS NULL THEN 'No Votes'
        WHEN pa.UpVotes > pa.DownVotes THEN 'Positive'
        WHEN pa.UpVotes < pa.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    TopPosts tp
LEFT JOIN 
    PostActivity pa ON tp.PostId = pa.PostId
WHERE 
    tp.PostId IN (
        SELECT 
            DISTINCT pl.PostId
        FROM 
            PostLinks pl
        JOIN 
            Posts p ON pl.RelatedPostId = p.Id
        WHERE 
            pl.LinkTypeId = 3 
            AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
    )
ORDER BY 
    tp.ViewCount DESC, 
    VoteSentiment DESC;
