
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS ViewCountRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),

PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TitleEditCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (6) THEN 1 ELSE 0 END) AS TagEditCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    us.UserId,
    us.DisplayName,
    us.QuestionCount,
    us.UpVotes,
    us.DownVotes,
    phc.EditCount,
    phc.TitleEditCount,
    phc.TagEditCount
FROM 
    RankedPosts rp
JOIN 
    Users u ON EXISTS (SELECT 1 FROM Posts p WHERE p.OwnerUserId = u.Id AND p.Id = rp.PostId)
JOIN 
    UserStats us ON us.UserId = u.Id
LEFT JOIN 
    PostHistoryCounts phc ON phc.PostId = rp.PostId
WHERE 
    rp.ScoreRank <= 10 AND rp.ViewCountRank <= 10
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
