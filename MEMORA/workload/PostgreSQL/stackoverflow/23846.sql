
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        pt.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT p.Id) AS PostedQuestions
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosureDetails AS (
    SELECT 
        ph.PostId,
        ph.Comment,
        ph.CreationDate,
        ph.UserDisplayName,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 10) AS CloseCount,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 11) AS ReopenCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId, ph.Comment, ph.CreationDate, ph.UserDisplayName
),
FinalReport AS (
    SELECT 
        rp.PostId,
        rp.Title,
        us.DisplayName AS Owner,
        us.TotalUpVotes,
        us.CommentCount,
        rp.Score,
        rp.ViewCount,
        COALESCE(cd.CloseCount, 0) AS CloseCount,
        COALESCE(cd.ReopenCount, 0) AS ReopenCount,
        CASE 
            WHEN us.PostedQuestions > 0 THEN 'Active Contributor'
            ELSE 'Lurker'
        END AS UserStatus
    FROM 
        RankedPosts rp
    JOIN 
        UserStatistics us ON rp.PostId = us.UserId
    LEFT JOIN 
        ClosureDetails cd ON rp.PostId = cd.PostId
    WHERE 
        rp.Rank <= 5
)

SELECT 
    *,
    CASE 
        WHEN ViewCount > 1000 AND CloseCount > 0 THEN 'Potentially Controversial Post'
        WHEN CloseCount = 0 AND ReopenCount > 0 THEN 'Recently Reopened'
        ELSE 'Normal Post'
    END AS PostStatus
FROM 
    FinalReport
ORDER BY 
    Score DESC, ViewCount DESC;
