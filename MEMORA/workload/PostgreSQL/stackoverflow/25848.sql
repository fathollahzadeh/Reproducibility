
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2) ORDER BY p.CreationDate DESC) AS TagGroupRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.ViewCount, p.Score
),
TopPostsByTag AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagGroupRank <= 3 
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.CreationDate
),
FinalBenchmark AS (
    SELECT 
        tpt.PostId,
        tpt.Title,
        tpt.Tags,
        tpt.CreationDate,
        tpt.ViewCount,
        tpt.Score,
        tpt.CommentCount,
        tpt.UpVoteCount,
        tpt.DownVoteCount,
        SUM(COALESCE(phs.EditCount, 0)) AS TotalEdits,
        COALESCE(SUM(CASE WHEN phs.PostHistoryTypeId = 4 THEN phs.EditCount END), 0) AS TitleEdits,
        COALESCE(SUM(CASE WHEN phs.PostHistoryTypeId = 5 THEN phs.EditCount END), 0) AS BodyEdits,
        COALESCE(SUM(CASE WHEN phs.PostHistoryTypeId = 6 THEN phs.EditCount END), 0) AS TagEdits
    FROM 
        TopPostsByTag tpt
    LEFT JOIN 
        PostHistorySummary phs ON tpt.PostId = phs.PostId
    GROUP BY 
        tpt.PostId, tpt.Title, tpt.Tags, tpt.CreationDate, tpt.ViewCount, tpt.Score, tpt.CommentCount, tpt.UpVoteCount, tpt.DownVoteCount
)
SELECT 
    PostId,
    Title,
    Tags,
    CreationDate,
    ViewCount,
    Score,
    CommentCount,
    UpVoteCount,
    DownVoteCount,
    TotalEdits,
    TitleEdits,
    BodyEdits,
    TagEdits
FROM 
    FinalBenchmark
ORDER BY 
    Score DESC, UpVoteCount DESC, ViewCount DESC;
