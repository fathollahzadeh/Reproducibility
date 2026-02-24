
WITH UserVoteCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVoteCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COALESCE(SUM(CASE WHEN c.PostId IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12)
),
LatestPostHistory AS (
    SELECT 
        postId,
        MAX(CreationDate) AS LastChangedDate
    FROM 
        PostHistoryDetails
    GROUP BY 
        postId
),
FullPostDetails AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.OwnerUserId,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        u.DisplayName AS OwnerDisplayName,
        upc.UpVoteCount AS OwnerUpVoteCount,
        downc.DownVoteCount AS OwnerDownVoteCount,
        lp.LastChangedDate,
        CASE 
            WHEN lp.LastChangedDate IS NULL THEN 'No History'
            ELSE 'History Exists'
        END AS HistoryStatus
    FROM 
        PostStatistics ps
    JOIN 
        Users u ON ps.OwnerUserId = u.Id
    LEFT JOIN 
        UserVoteCounts upc ON ps.OwnerUserId = upc.UserId
    LEFT JOIN 
        UserVoteCounts downc ON ps.OwnerUserId = downc.UserId
    LEFT JOIN 
        LatestPostHistory lp ON ps.PostId = lp.PostId
)
SELECT 
    fpd.PostId,
    fpd.Title,
    fpd.OwnerDisplayName,
    fpd.CommentCount,
    fpd.UpVoteCount,
    fpd.DownVoteCount,
    fpd.OwnerUpVoteCount,
    fpd.OwnerDownVoteCount,
    fpd.LastChangedDate,
    fpd.HistoryStatus
FROM 
    FullPostDetails fpd
WHERE 
    fpd.CommentCount > 3 
    OR fpd.UpVoteCount - fpd.DownVoteCount > 10
ORDER BY 
    fpd.CommentCount DESC, fpd.UpVoteCount DESC;
