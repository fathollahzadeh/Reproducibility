
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), 0) AS AcceptedAnswer
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserInteractions AS (
    SELECT 
        u.Id AS UserId, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        COUNT(DISTINCT c.Id) AS CommentsCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    GROUP BY 
        u.Id
),
PostSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        ui.UpVotesCount,
        ui.DownVotesCount,
        ui.CommentsCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserInteractions ui ON ui.UserId = rp.AcceptedAnswer
    WHERE 
        rp.Rank <= 10
)
SELECT 
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.UpVotesCount,
    ps.DownVotesCount,
    ps.CommentsCount,
    CASE 
        WHEN ps.UpVotesCount > ps.DownVotesCount THEN 'Positive'
        WHEN ps.UpVotesCount < ps.DownVotesCount THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = ps.PostId) AS TotalComments
FROM 
    PostSummary ps
ORDER BY 
    ps.Score DESC
LIMIT 20;
