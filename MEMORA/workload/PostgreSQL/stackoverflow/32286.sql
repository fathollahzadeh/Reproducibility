
WITH RecursivePostHistory AS (
    SELECT 
        Id,
        PostHistoryTypeId,
        PostId,
        CreationDate,
        UserId,
        UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY PostId ORDER BY CreationDate DESC) AS rn
    FROM 
        PostHistory
), 
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        MAX(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS HasGoldBadge,
        MAX(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS HasSilverBadge,
        MAX(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS HasBronzeBadge
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        COUNT(DISTINCT c.Id) AS CommentsMade,
        COUNT(DISTINCT b.Id) AS BadgesEarned
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.PostCreationDate,
    ps.NetVotes,
    ps.CommentCount,
    ua.UserId,
    ua.DisplayName,
    ua.PostsCreated,
    ua.CommentsMade,
    ua.BadgesEarned,
    CASE 
        WHEN ps.NetVotes > 0 THEN 'Positive' 
        WHEN ps.NetVotes < 0 THEN 'Negative' 
        ELSE 'Neutral' 
    END AS VoteSentiment,
    CASE 
        WHEN EXISTS (SELECT 1 FROM RecursivePostHistory rph WHERE rph.PostId = ps.PostId AND rph.PostHistoryTypeId IN (10, 11)) 
        THEN 'Closed/Reopened' 
        ELSE 'Active' 
    END AS PostStatus
FROM 
    PostStats ps
JOIN 
    Users u ON ps.PostId = u.Id
JOIN 
    UserActivity ua ON u.Id = ua.UserId
WHERE 
    ps.CommentCount > 5 
ORDER BY 
    ps.NetVotes DESC, ps.PostCreationDate DESC;
