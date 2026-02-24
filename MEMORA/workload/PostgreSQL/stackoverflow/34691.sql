WITH RecursivePostHistory AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate,
        ph.Comment,
        ph.PostHistoryTypeId,
        ph.UserId,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (1, 2, 4, 5, 10)
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
UserVotes AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.UserId, -1) AS UserId,
        COALESCE(v.VoteCount, 0) AS VoteCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        COALESCE(b.BadgeNames, 'No Badges') AS BadgeNames,
        ROW_NUMBER() OVER (ORDER BY COALESCE(c.CommentCount, 0) DESC, p.CreationDate ASC) AS PopularityRank
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        UserVotes v ON p.OwnerUserId = v.UserId
    LEFT JOIN 
        UserBadges b ON p.OwnerUserId = b.UserId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.AnswerCount,
    ps.CommentCount,
    ps.VoteCount,
    ps.BadgeCount,
    ps.BadgeNames,
    rph.CreationDate AS LatestHistoryDate,
    CASE 
        WHEN ps.PopularityRank <= 5 THEN 'Top Posts'
        ELSE 'Other Posts'
    END AS Category
FROM 
    PostStatistics ps
LEFT JOIN 
    RecursivePostHistory rph ON ps.PostId = rph.PostId AND rph.HistoryRank = 1
WHERE 
    ps.BadgeCount > 0
ORDER BY 
    ps.VoteCount DESC, ps.CommentCount DESC;
