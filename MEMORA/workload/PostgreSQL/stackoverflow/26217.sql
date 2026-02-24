
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        COUNT(c.Id) AS TotalComments,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        COALESCE(MAX(b.Class), 0) AS HighestBadgeClass,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        PostLinks pl ON pl.PostId = p.Id
    LEFT JOIN 
        Tags t ON t.Id = pl.RelatedPostId
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.AnswerCount, p.CommentCount, p.FavoriteCount
),
RankedPosts AS (
    SELECT 
        ps.*,
        ROW_NUMBER() OVER (ORDER BY ps.ViewCount DESC, ps.AnswerCount DESC) AS Rank
    FROM 
        PostStatistics ps
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.FavoriteCount,
    rp.TotalComments,
    rp.Tags,
    rp.HighestBadgeClass,
    rp.UpVotes,
    rp.DownVotes,
    rp.Rank
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Rank;
