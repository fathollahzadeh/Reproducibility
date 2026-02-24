
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2022-01-01' 
        AND p.Score >= 0
    GROUP BY 
        p.Id, U.DisplayName, p.PostTypeId, p.Title, p.Score, p.CreationDate, p.ViewCount
),

TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        CreationDate,
        OwnerDisplayName,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)

SELECT 
    tp.Title,
    tp.Score,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.CommentCount,
    COALESCE(tp.UpVotes, 0) AS TotalUpVotes,
    COALESCE(tp.DownVotes, 0) AS TotalDownVotes,
    CASE 
        WHEN tp.UpVotes = 0 THEN 'No Votes'
        WHEN tp.UpVotes > tp.DownVotes THEN 'Trending Up'
        ELSE 'Trending Down'
    END AS TrendDirection,
    (SELECT COUNT(*) FROM Posts WHERE ViewCount > 1000) AS HighTrafficPosts
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC;
