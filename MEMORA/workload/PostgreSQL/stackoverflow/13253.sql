
WITH UserPostStats AS (
    SELECT
        u.Id AS UserID,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
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
)

SELECT
    ups.UserID,
    ups.DisplayName,
    ups.PostCount,
    ups.Questions,
    ups.Answers,
    ups.TotalScore,
    ups.TotalViews,
    ups.UpVotes,
    ups.DownVotes,
    u.Reputation,
    u.CreationDate,
    u.LastAccessDate
FROM 
    UserPostStats ups
JOIN 
    Users u ON ups.UserID = u.Id
ORDER BY 
    ups.PostCount DESC, ups.TotalScore DESC;
