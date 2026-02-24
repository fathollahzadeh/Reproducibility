WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.Reputation AS OwnerReputation,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2020-01-01' 
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 4 THEN 1 ELSE 0 END) AS TitleEdits,
        SUM(CASE WHEN ph.PostHistoryTypeId = 6 THEN 1 ELSE 0 END) AS TagEdits,
        SUM(CASE WHEN ph.PostHistoryTypeId = 5 THEN 1 ELSE 0 END) AS BodyEdits
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserEngagement AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount + ue.CommentCount AS TotalComments,
    ps.FavoriteCount,
    ps.OwnerReputation,
    ps.OwnerDisplayName,
    COALESCE(phs.EditCount, 0) AS TotalEdits,
    COALESCE(phs.TitleEdits, 0) AS TitleEdits,
    COALESCE(phs.TagEdits, 0) AS TagEdits,
    COALESCE(phs.BodyEdits, 0) AS BodyEdits,
    COALESCE(ue.VoteCount, 0) AS TotalVotes
FROM 
    PostStats ps
LEFT JOIN 
    PostHistoryStats phs ON ps.PostId = phs.PostId
LEFT JOIN 
    UserEngagement ue ON ps.PostId = ue.PostId
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC 
LIMIT 100;