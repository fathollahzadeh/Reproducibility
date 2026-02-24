
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.LastActivityDate,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Posts a WHERE a.ParentId = p.Id), 0) AS AnswerCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        MAX(ph.CreationDate) AS LastEdit,
        MAX(ph.UserDisplayName) AS LastEditor
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6) 
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.Score, p.ViewCount, p.CreationDate, p.LastActivityDate
), RankedPosts AS (
    SELECT 
        ps.*,
        ROW_NUMBER() OVER (ORDER BY ps.Score DESC, ps.ViewCount DESC, ps.CreationDate ASC) AS Rank
    FROM 
        PostStatistics ps
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.AnswerCount,
    rp.BadgeNames,
    rp.LastEdit,
    rp.LastEditor
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 50 
ORDER BY 
    rp.Rank;
