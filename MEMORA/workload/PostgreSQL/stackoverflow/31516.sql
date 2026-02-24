
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
), 
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        u.DisplayName AS EditorName,
        ph.Comment,
        ph.Text
    FROM 
        PostHistory ph
    LEFT JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12)  
), 
TagCounts AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', Tags.TagName, '%')
    GROUP BY 
        Tags.TagName
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    phd.HistoryDate,
    phd.EditorName,
    phd.Comment,
    tc.TagName,
    ua.DisplayName AS UserDisplayName,
    ua.VoteCount,
    ua.UpVotes,
    ua.DownVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
LEFT JOIN 
    TagCounts tc ON EXISTS (
        SELECT 1 
        FROM Tags t 
        WHERE rp.Title LIKE CONCAT('%', t.TagName, '%')
    )
LEFT JOIN 
    UserActivity ua ON ua.UserId = rp.PostId 
WHERE 
    rp.RankByScore <= 5  
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
