
WITH RecursiveUserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        COALESCE(v.VoteCount, 0) AS VoteCount,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS RN
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) b ON u.Id = b.UserId
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS VoteCount
        FROM 
            Votes 
        WHERE 
            VoteTypeId = 2 
        GROUP BY 
            UserId
    ) v ON u.Id = v.UserId
), 
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.OwnerUserId, p.PostTypeId, p.CreationDate, p.Score, p.ViewCount
), 
FilteredPosts AS (
    SELECT 
        pd.PostId,
        pd.OwnerUserId,
        pd.PostTypeId,
        pd.CreationDate,
        pd.Score,
        pd.ViewCount,
        pd.CommentCount,
        pd.UpVoteCount,
        pd.DownVoteCount,
        (pd.UpVoteCount - pd.DownVoteCount) AS NetScore,
        CASE 
            WHEN pd.PostTypeId = 1 THEN 'Question' 
            WHEN pd.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostType
    FROM 
        PostDetails pd
    WHERE 
        pd.Score >= 0
), 
TopUsers AS (
    SELECT 
        rus.UserId,
        rus.DisplayName,
        rus.BadgeCount,
        rus.VoteCount,
        RANK() OVER (ORDER BY rus.Reputation DESC) AS UserRank
    FROM 
        RecursiveUserStats rus
    WHERE 
        rus.VoteCount > 10
), 
UserPostStats AS (
    SELECT 
        fu.UserId,
        fu.DisplayName,
        fp.PostId,
        fp.PostType,
        fp.NetScore,
        fp.CreationDate,
        COUNT(pv.PostId) AS UserPostVoteCount,
        COUNT(DISTINCT fc.Id) AS UserCommentCount
    FROM 
        FilteredPosts fp
    JOIN 
        TopUsers fu ON fp.OwnerUserId = fu.UserId
    LEFT JOIN 
        Votes pv ON fp.PostId = pv.PostId AND pv.UserId = fu.UserId
    LEFT JOIN 
        Comments fc ON fp.PostId = fc.PostId AND fc.UserId = fu.UserId
    GROUP BY 
        fu.UserId, fu.DisplayName, fp.PostId, fp.PostType, fp.NetScore, fp.CreationDate
)
SELECT 
    ups.DisplayName,
    COUNT(ups.PostId) AS TotalPosts,
    SUM(ups.UserPostVoteCount) AS TotalUserVotes,
    SUM(ups.UserCommentCount) AS TotalComments,
    AVG(ups.NetScore) AS AverageNetScore
FROM 
    UserPostStats ups
WHERE
    ups.NetScore > 0
GROUP BY 
    ups.DisplayName
HAVING 
    COUNT(ups.PostId) > 5
ORDER BY 
    AverageNetScore DESC
LIMIT 10;
