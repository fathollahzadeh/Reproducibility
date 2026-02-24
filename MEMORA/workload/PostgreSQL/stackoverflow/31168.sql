WITH Recursive PostCTE AS (
    SELECT 
        Id,
        PostTypeId,
        ParentId,
        Title,
        Score,
        OwnerUserId,
        CreationDate,
        1 AS Depth
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  

    UNION ALL

    SELECT 
        p.Id,
        p.PostTypeId,
        p.ParentId,
        p.Title,
        p.Score,
        p.OwnerUserId,
        p.CreationDate,
        pc.Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        PostCTE pc ON p.ParentId = pc.Id  
    WHERE 
        p.PostTypeId = 2  
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostVoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(pv.UpVotes, 0) AS UpVotes,
        COALESCE(pv.DownVotes, 0) AS DownVotes,
        COALESCE(b.BadgeCount, 0) AS UserBadgeCount,
        COALESCE(b.BadgeNames, 'No Badges') AS UserBadgeNames,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        PostVoteSummary pv ON p.Id = pv.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UserBadges b ON u.Id = b.UserId
),

TopPosts AS (
    SELECT 
        p.PostId,
        p.Title,
        p.UpVotes,
        p.DownVotes,
        p.UserBadgeCount,
        p.UserBadgeNames,
        (p.UpVotes - p.DownVotes) AS Score
    FROM 
        PostMetrics p
    WHERE 
        p.RowNum <= 100
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.UpVotes,
    tp.DownVotes,
    tp.Score,
    tp.UserBadgeCount,
    tp.UserBadgeNames,
    pc.Depth AS AnswerDepth
FROM 
    TopPosts tp
LEFT JOIN 
    PostCTE pc ON tp.PostId = pc.Id
ORDER BY 
    tp.Score DESC, 
    tp.UpVotes DESC;